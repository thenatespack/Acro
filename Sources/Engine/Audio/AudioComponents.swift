// ECS components for 3D audio. An entity with an `AudioListener` and a transform is the
// listener (the first one found); an entity with an `AudioEmitter` plays its registered sound
// from its transform. Both serialize with scenes. `World.addSpatialAudio` adds the system that
// reads `GlobalTransform`s after transform propagation and drives `AudioSystem.listener` and the
// emitters' voices.

/// The ears: the entity's world position and orientation (forward is -Z) set `AudioSystem.listener`.
/// With several, the first one in storage order is used.
public struct AudioListener: Component, Codable, Equatable, Sendable {
    public static let componentName = "AudioListener"
    public static var fieldHints: [String: FieldHints] {
        ["volume": FieldHints(range: 0...4, step: 0.01),
         "speedOfSound": FieldHints(range: 1...2000, step: 1, tooltip: "Meters per second"),
         "headShadow": FieldHints(range: 0...1, step: 0.01, tooltip: "How much the far ear is muffled (0 = off)"),
         "velocity": FieldHints(tooltip: "Empty derives it from the entity's movement")]
    }

    /// Master gain for every spatial voice.
    public var volume: Float = 1
    public var speedOfSound: Float = 343
    public var headShadow: Float = 1
    /// nil derives it from how the entity moves.
    public var velocity: Vec3?

    public init(volume: Float = 1, speedOfSound: Float = 343, headShadow: Float = 1, velocity: Vec3? = nil) {
        self.volume = volume
        self.speedOfSound = speedOfSound
        self.headShadow = headShadow
        self.velocity = velocity
    }
}

/// A sound source at the entity's position. `sound` names a buffer registered with
/// `AudioSystem.register(_:as:)`. The voice starts when `isPlaying` is true and no voice is
/// running; a sound that isn't `loop`ing clears `isPlaying` when it ends (set it again to replay).
/// Turning `isPlaying` off, removing the component or despawning the entity stops the voice.
public struct AudioEmitter: Component, Codable, Equatable, Sendable {
    public static let componentName = "AudioEmitter"
    public static var fieldHints: [String: FieldHints] {
        ["volume": FieldHints(range: 0...4, step: 0.01), "pitch": FieldHints(range: 0.1...4, step: 0.01),
         "reverbSend": FieldHints(range: 0...1, step: 0.01),
         "sound": FieldHints(tooltip: "Name of a sound registered with AudioSystem.register(_:as:)"),
         "velocity": FieldHints(tooltip: "Empty derives it from the entity's movement")]
    }

    public var sound: String
    /// Name of the bus to play on.
    public var bus: String
    public var volume: Float
    public var pitch: Float
    public var loop: Bool
    public var isPlaying: Bool
    public var spatial: SpatialSettings
    /// Level sent to the bus named `reverbBus` (0 for none).
    public var reverbSend: Float
    public var reverbBus: String
    /// A per-voice filter, if any.
    public var filter: AudioFilter?
    /// nil derives it from how the entity moves.
    public var velocity: Vec3?

    public init(sound: String = "", bus: String = "sfx", volume: Float = 1, pitch: Float = 1, loop: Bool = true,
                isPlaying: Bool = true, spatial: SpatialSettings = SpatialSettings(), reverbSend: Float = 0,
                reverbBus: String = "reverb", filter: AudioFilter? = nil, velocity: Vec3? = nil) {
        self.sound = sound
        self.bus = bus
        self.volume = volume
        self.pitch = pitch
        self.loop = loop
        self.isPlaying = isPlaying
        self.spatial = spatial
        self.reverbSend = reverbSend
        self.reverbBus = reverbBus
        self.filter = filter
        self.velocity = velocity
    }
}

extension AudioSystem {
    /// Registers the audio components with `ComponentRegistry` (done by `addSpatialAudio`, and
    /// needed before loading scene files that use them into a world that hasn't seen them).
    @MainActor public static func registerComponents() {
        ComponentRegistry.register(AudioListener.self, AudioEmitter.self)
    }
}

/// The voices of one world's emitters.
@MainActor
final class SpatialAudioBinding {
    struct Playing {
        var voice: Voice
        var sound: String
    }

    var playing: [Entity: Playing] = [:]

    func stopAll() {
        for (_, p) in playing { p.voice.stop() }
        playing = [:]
    }
}

extension World {
    /// Drives `audio` from this world's `AudioListener` and `AudioEmitter` components: adds a
    /// `.renderPrep` system "audio.spatial" (after transforms are propagated) that sets the
    /// listener pose, starts and stops emitter voices, and updates their position, direction,
    /// volume, pitch, settings, filter and reverb send. Velocities for Doppler come from the
    /// entities' movement unless set.
    public func addSpatialAudio(_ audio: AudioSystem) {
        AudioSystem.registerComponents()
        let binding = SpatialAudioBinding()
        addSystem("audio.spatial", stage: .renderPrep) { world in
            var listenerFound = false
            world.query(AudioListener.self, GlobalTransform.self) { _, listener, global in
                guard !listenerFound else { return }
                listenerFound = true
                var state = audio.listener
                state.position = Vec3(global.matrix.c3.x, global.matrix.c3.y, global.matrix.c3.z)
                state.forward = normalize(-Vec3(global.matrix.c2.x, global.matrix.c2.y, global.matrix.c2.z))
                state.up = normalize(Vec3(global.matrix.c1.x, global.matrix.c1.y, global.matrix.c1.z))
                state.velocity = listener.velocity
                state.volume = listener.volume
                state.speedOfSound = listener.speedOfSound
                state.headShadow = listener.headShadow
                audio.listener = state
            }

            var seen = Set<Entity>()
            world.queryMutating(AudioEmitter.self, GlobalTransform.self) { entity, emitter, global in
                seen.insert(entity)
                let position = Vec3(global.matrix.c3.x, global.matrix.c3.y, global.matrix.c3.z)
                let forward = normalize(-Vec3(global.matrix.c2.x, global.matrix.c2.y, global.matrix.c2.z))
                if var current = binding.playing[entity] {
                    if !current.voice.isPlaying {
                        // Ended on its own.
                        binding.playing[entity] = nil
                        emitter.isPlaying = false
                        return
                    }
                    if !emitter.isPlaying || current.sound != emitter.sound {
                        current.voice.stop()
                        binding.playing[entity] = nil
                        if !emitter.isPlaying { return }
                    } else {
                        Self.apply(emitter, position: position, forward: forward, to: current.voice, audio: audio)
                        return
                    }
                }
                guard emitter.isPlaying, let buffer = audio.sound(named: emitter.sound) else { return }
                let bus = audio.bus(named: emitter.bus) ?? audio.sfx
                let voice = audio.play(buffer, at: position, settings: emitter.spatial, on: bus, volume: emitter.volume,
                                       pitch: emitter.pitch, loop: emitter.loop)
                guard voice.isValid else { return }
                voice.worldDirection = forward
                voice.worldVelocity = emitter.velocity
                Self.apply(emitter, position: position, forward: forward, to: voice, audio: audio)
                binding.playing[entity] = SpatialAudioBinding.Playing(voice: voice, sound: emitter.sound)
            }
            for (entity, current) in binding.playing where !seen.contains(entity) {
                current.voice.stop()
                binding.playing[entity] = nil
            }
        }
    }

    @MainActor
    private static func apply(_ emitter: AudioEmitter, position: Vec3, forward: Vec3, to voice: Voice, audio: AudioSystem) {
        voice.worldPosition = position
        voice.worldDirection = forward
        voice.worldVelocity = emitter.velocity
        voice.spatial = emitter.spatial
        if voice.volume != emitter.volume { voice.volume = emitter.volume }
        if voice.pitch != emitter.pitch { voice.pitch = emitter.pitch }
        voice.filter = emitter.filter
        if emitter.reverbSend > 0, let bus = audio.bus(named: emitter.reverbBus) {
            if voice.sendBus != bus || voice.sendLevel != emitter.reverbSend { voice.setSend(to: bus, level: emitter.reverbSend) }
        } else if voice.sendBus != nil {
            voice.setSend(to: nil, level: 0)
        }
    }
}
