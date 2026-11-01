import Foundation

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
/// `AudioSystem.register(_:as:)`; `clip` (when set) is an `asset:<id>` key of a project audio
/// file instead, decoded off the main thread on first use and cached (needs the asset database
/// given to `addSpatialAudio(_:assets:)`; the editor's play mode and packaged games do that).
/// The sound plays once decoded, `loop` and `isPlaying` as usual. The voice starts when `isPlaying` is true and no voice is
/// running; a sound that isn't `loop`ing clears `isPlaying` when it ends (set it again to replay).
/// Turning `isPlaying` off, removing the component or despawning the entity stops the voice.
public struct AudioEmitter: Component, Codable, Equatable, Sendable {
    public static let componentName = "AudioEmitter"
    public static var fieldHints: [String: FieldHints] {
        ["volume": FieldHints(range: 0...4, step: 0.01), "pitch": FieldHints(range: 0.1...4, step: 0.01),
         "reverbSend": FieldHints(range: 0...1, step: 0.01),
         "sound": FieldHints(tooltip: "Name of a sound registered with AudioSystem.register(_:as:)"),
         "clip": FieldHints(tooltip: "A project audio asset (wav/ogg/mp3/flac); takes priority over sound"),
         "velocity": FieldHints(tooltip: "Empty derives it from the entity's movement")]
    }

    public var sound: String
    /// An `asset:<id>` key of a project audio file ("" for none); wins over `sound`.
    public var clip: String
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

    public init(sound: String = "", clip: String = "", bus: String = "sfx", volume: Float = 1, pitch: Float = 1, loop: Bool = true,
                isPlaying: Bool = true, spatial: SpatialSettings = SpatialSettings(), reverbSend: Float = 0,
                reverbBus: String = "reverb", filter: AudioFilter? = nil, velocity: Vec3? = nil) {
        self.sound = sound
        self.clip = clip
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

    private enum CodingKeys: String, CodingKey {
        case sound, clip, bus, volume, pitch, loop, isPlaying, spatial, reverbSend, reverbBus, filter, velocity
    }

    /// Scenes saved before `clip` existed load with none.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        sound = try c.decode(String.self, forKey: .sound)
        clip = try c.decodeIfPresent(String.self, forKey: .clip) ?? ""
        bus = try c.decode(String.self, forKey: .bus)
        volume = try c.decode(Float.self, forKey: .volume)
        pitch = try c.decode(Float.self, forKey: .pitch)
        loop = try c.decode(Bool.self, forKey: .loop)
        isPlaying = try c.decode(Bool.self, forKey: .isPlaying)
        spatial = try c.decode(SpatialSettings.self, forKey: .spatial)
        reverbSend = try c.decode(Float.self, forKey: .reverbSend)
        reverbBus = try c.decode(String.self, forKey: .reverbBus)
        filter = try c.decodeIfPresent(AudioFilter.self, forKey: .filter)
        velocity = try c.decodeIfPresent(Vec3.self, forKey: .velocity)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(sound, forKey: .sound)
        try c.encode(clip, forKey: .clip)
        try c.encode(bus, forKey: .bus)
        try c.encode(volume, forKey: .volume)
        try c.encode(pitch, forKey: .pitch)
        try c.encode(loop, forKey: .loop)
        try c.encode(isPlaying, forKey: .isPlaying)
        try c.encode(spatial, forKey: .spatial)
        try c.encode(reverbSend, forKey: .reverbSend)
        try c.encode(reverbBus, forKey: .reverbBus)
        try c.encodeIfPresent(filter, forKey: .filter)
        try c.encodeIfPresent(velocity, forKey: .velocity)
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

    /// Decoded clips by asset; clips being decoded; failures (reported once, not retried).
    private var clips: [AssetID: SoundBuffer] = [:]
    private var loading = Set<AssetID>()
    private var failed = Set<AssetID>()
    private let mailbox = ClipMailbox()
    private let assets: () -> AssetDatabase?

    init(assets: @escaping () -> AssetDatabase?) { self.assets = assets }

    func stopAll() {
        for (_, p) in playing { p.voice.stop() }
        playing = [:]
    }

    /// Takes finished decodes (call once per frame).
    func pump() {
        for (id, result) in mailbox.take() {
            loading.remove(id)
            switch result {
            case .success(let buffer): clips[id] = buffer
            case .failure(let error):
                failed.insert(id)
                print("AudioEmitter: could not load \(id): \(error)")
            }
        }
    }

    /// The buffer an emitter plays: its decoded clip (starting the decode on first use; nil
    /// until done), else the registered sound.
    func buffer(for emitter: AudioEmitter, audio: AudioSystem) -> SoundBuffer? {
        guard !emitter.clip.isEmpty else { return audio.sound(named: emitter.sound) }
        guard let reference = AssetReference(emitter.clip) ?? AssetID(emitter.clip).map({ AssetReference($0) }) else {
            return audio.sound(named: emitter.sound)
        }
        let id = reference.asset
        if let buffer = clips[id] { return buffer }
        guard !loading.contains(id), !failed.contains(id), let assets = assets() else { return nil }
        let name = assets.path(of: id).map { (($0 as NSString).lastPathComponent as NSString).deletingPathExtension } ?? ""
        let source: ClipMailbox.Source
        if assets.pack != nil {
            guard let data = try? assets.fileData(of: id) else {
                failed.insert(id)
                print("AudioEmitter: no audio asset \(id)")
                return nil
            }
            source = .data(data)
        } else if let url = assets.sourceURL(of: id) {
            source = .url(url)
        } else {
            failed.insert(id)
            print("AudioEmitter: no audio asset \(id)")
            return nil
        }
        loading.insert(id)
        mailbox.decode(id, source, name: name)
        return nil
    }
}

/// Decodes clips on background threads and holds the results until the main actor takes them.
final class ClipMailbox: @unchecked Sendable {
    enum Source: Sendable {
        case url(URL)
        case data(Data)
    }

    private let lock = NSLock()
    private var done: [(AssetID, Result<SoundBuffer, Error>)] = []

    func decode(_ id: AssetID, _ source: Source, name: String) {
        DispatchQueue.global(qos: .utility).async { [self] in
            let result = Result<SoundBuffer, Error> {
                switch source {
                case .url(let url): try SoundBuffer(decoder: AudioFile.decoder(contentsOf: url), name: name)
                case .data(let data): try SoundBuffer(data: data, name: name)
                }
            }
            lock.withLock { done.append((id, result)) }
        }
    }

    func take() -> [(AssetID, Result<SoundBuffer, Error>)] {
        lock.withLock {
            defer { done = [] }
            return done
        }
    }
}

/// What `World.addSpatialAudio` returns: `remove()` takes the system out of the world and stops its voices.
@MainActor
public final class SpatialAudioHandle {
    private weak var world: World?
    private let binding: SpatialAudioBinding

    init(world: World, binding: SpatialAudioBinding) {
        self.world = world
        self.binding = binding
    }

    public func remove() {
        binding.stopAll()
        world?.removeSystem(named: "audio.spatial")
    }
}

extension World {
    /// Drives `audio` from this world's `AudioListener` and `AudioEmitter` components: adds a
    /// `.renderPrep` system "audio.spatial" (after transforms are propagated) that sets the
    /// listener pose, starts and stops emitter voices, and updates their position, direction,
    /// volume, pitch, settings, filter and reverb send. Velocities for Doppler come from the
    /// entities' movement unless set.
    ///
    /// `assets` supplies the database that emitters' `clip` assets load from (decoded on a
    /// background thread, cached per asset; the emitter starts when it is ready). An existing
    /// "audio.spatial" system is replaced. Returns the handle that removes the system and
    /// stops its voices.
    @discardableResult
    public func addSpatialAudio(_ audio: AudioSystem, assets: @escaping () -> AssetDatabase? = { nil }) -> SpatialAudioHandle {
        AudioSystem.registerComponents()
        let binding = SpatialAudioBinding(assets: assets)
        removeSystem(named: "audio.spatial")
        addSystem("audio.spatial", stage: .renderPrep) { world in
            binding.pump()
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
                    if !emitter.isPlaying || current.sound != Self.soundKey(emitter) {
                        current.voice.stop()
                        binding.playing[entity] = nil
                        if !emitter.isPlaying { return }
                    } else {
                        Self.apply(emitter, position: position, forward: forward, to: current.voice, audio: audio)
                        return
                    }
                }
                guard emitter.isPlaying, let buffer = binding.buffer(for: emitter, audio: audio) else { return }
                let bus = audio.bus(named: emitter.bus) ?? audio.sfx
                let voice = audio.play(buffer, at: position, settings: emitter.spatial, on: bus, volume: emitter.volume,
                                       pitch: emitter.pitch, loop: emitter.loop)
                guard voice.isValid else { return }
                voice.worldDirection = forward
                voice.worldVelocity = emitter.velocity
                Self.apply(emitter, position: position, forward: forward, to: voice, audio: audio)
                binding.playing[entity] = SpatialAudioBinding.Playing(voice: voice, sound: Self.soundKey(emitter))
            }
            for (entity, current) in binding.playing where !seen.contains(entity) {
                current.voice.stop()
                binding.playing[entity] = nil
            }
        }
        return SpatialAudioHandle(world: self, binding: binding)
    }

    private static func soundKey(_ emitter: AudioEmitter) -> String { emitter.clip.isEmpty ? emitter.sound : "clip:" + emitter.clip }

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
