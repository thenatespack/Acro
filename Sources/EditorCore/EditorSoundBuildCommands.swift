import Engine
import Foundation

/// The sound builder tools: `sfx.new`, `sfx.get`, `sfx.set`, `sfx.edit`, `sfx.play`, `sfx.open`;
/// and for every sound asset `audio.info` and `audio.preview` (AudioInspector.swift).
@MainActor
public enum EditorSoundBuildCommands {
    public static let all: [any EditorCommand.Type] = [
        SoundBuildNewCommand.self,
        SoundBuildGetCommand.self,
        SoundBuildSetCommand.self,
        SoundBuildEditCommand.self,
        SoundBuildPlayCommand.self,
        SoundBuildOpenCommand.self,
        AudioInfoCommand.self,
        AudioPreviewCommand.self,
    ]

    /// What the tool docs say about the file format, shared by the tools.
    static let formatDoc = """
        A sound build is a synthesized effect (every key optional): waveform square|saw|sine|noise, frequency Hz, slide \
        (octaves/second, negative falls), slideAcceleration, minFrequency (the sound ends when the pitch falls below it), \
        vibratoDepth (semitones) and vibratoRate (Hz), arpeggio (semitone jump after arpeggioTime seconds), duty and \
        dutySweep (square pulse width), attack / sustain / decay (seconds), punch 0-1, lowPass / highPass (Hz, 0 = off), \
        bitCrush (bits 1-15, 0 = off), volume 0-1, sampleRate, seed (drives the noise: the same parameters and seed give \
        identical samples). Presets: jump|coin|laser|explosion|hit|powerUp|blip. The file plays anywhere an audio file does: \
        set an AudioEmitter's `clip` to it.
        """

    /// Number of waveform peaks the tools return.
    static let peakCount = 48
}

/// The sound being previewed in the editor (a new preview replaces it).
@MainActor
enum SoundBuildPreview {
    /// Plays `build`; false when the editor has no audio device.
    @discardableResult
    static func play(_ build: SoundBuild, in session: EditorSession) -> Bool {
        SoundPreview.play(.build(build), in: session)
    }
}

/// The editor's sound preview: one sound at a time, on the sfx bus, from the Sound Builder or a
/// click on a sound elsewhere (an audio file in the asset browser, a Timeline audio key).
/// Starting one stops the last.
enum SoundPreview {
    /// What a preview plays.
    enum Source: Equatable, Sendable {
        /// A `.sfx` sound build, synthesized.
        case build(SoundBuild)
        /// An audio file in the project, streamed from its source.
        case file(URL)
    }

    @MainActor private static var voice: Voice?
    /// The asset `voice` plays, when it came from one.
    @MainActor private static var voiceAsset: AssetID?
    /// When the voice started, from where (seconds into the sound), how long the sound is (when
    /// known), whether it loops and at what pitch: the playhead (`playhead`).
    @MainActor private static var started: (date: Date, offset: Double, duration: Double?, loop: Bool, pitch: Float)?
    /// A file starting part way in: its decoder skips to the start off the main thread; this
    /// counts plays so a stale one doesn't start after a newer one (or a stop).
    @MainActor private static var generation = 0
    @MainActor private static var loadingAsset: AssetID?
    /// The play waiting for its skipped decoder, and where the background task leaves it. The
    /// main thread collects it (`pump`) instead of the task hopping to the main actor, so it
    /// works however the host runs its loop.
    @MainActor private static var starting: (ticket: Int, volume: Float, pitch: Float, loop: Bool, offset: Double, duration: Double?, url: URL)?
    @MainActor private static weak var startSession: EditorSession?
    private static let startMailbox = Mailbox()

    private final class Mailbox: @unchecked Sendable {
        private let lock = NSLock()
        private var value: (ticket: Int, box: DecoderBox?)?
        func post(_ ticket: Int, _ box: DecoderBox?) { lock.withLock { value = (ticket, box) } }
        func take() -> (ticket: Int, box: DecoderBox?)? { lock.withLock { defer { value = nil }; return value } }
    }

    /// Starts a file whose decoder finished skipping to its start. Called by the accessors
    /// below (the inspector reads them every frame) and every editor frame.
    @MainActor static func pump() {
        guard let pending = starting, let result = startMailbox.take() else { return }
        guard result.ticket == pending.ticket else { return }
        starting = nil
        loadingAsset = nil
        guard let session = startSession else { return }
        guard let box = result.box, let audio = session.audioProvider?() else {
            session.log.warning("Sound preview: can't play \(pending.url.lastPathComponent)")
            return
        }
        voice = audio.playStream(box.decoder, on: audio.sfx, volume: pending.volume, pitch: pending.pitch, loop: pending.loop,
                                 name: pending.url.deletingPathExtension().lastPathComponent)
        started = (Date(), pending.offset, pending.duration, pending.loop, pending.pitch)
    }

    /// A file is skipping to where it starts (its voice begins after).
    @MainActor static var isStarting: Bool {
        pump()
        return loadingAsset != nil
    }

    /// The sound asset playing (or about to, while a file skips to its start); nil when none is.
    @MainActor static var playingAsset: AssetID? {
        pump()
        if let loadingAsset { return loadingAsset }
        return voice?.isPlaying == true ? voiceAsset : nil
    }

    /// Seconds into the sound the preview is at; nil when nothing plays.
    @MainActor static var playhead: Double? {
        guard voice?.isPlaying == true || loadingAsset != nil, let started else { return nil }
        let t = started.offset + Date().timeIntervalSince(started.date) * Double(started.pitch)
        guard let duration = started.duration, duration > 0 else { return t }
        if t < duration { return t }
        return started.loop ? (t - duration).truncatingRemainder(dividingBy: duration) : duration
    }

    /// The sound `clip` names (a path under `Assets/` or "asset:<id>", as a Timeline audio key or
    /// a data table writes it): an audio file or a `.sfx`. nil when it names no sound.
    @MainActor static func source(of clip: String, in assets: AssetDatabase) -> Source? {
        assets.assetID(forTableValue: clip).flatMap { source(of: $0, in: assets) }
    }

    /// The sound asset `id` is: an audio file or a `.sfx`. nil for anything else.
    @MainActor static func source(of id: AssetID, in assets: AssetDatabase) -> Source? {
        if let build = assets.soundBuild(of: id) { return .build(build) }
        guard assets.record(id)?.importer == AudioImporter().name, let url = assets.sourceURL(of: id) else { return nil }
        return .file(url)
    }

    /// Hands a decoder from the task that skipped it to its start to the main actor.
    private final class DecoderBox: @unchecked Sendable {
        let decoder: AudioDecoder
        init(_ decoder: AudioDecoder) { self.decoder = decoder }
    }

    /// A decoder already `skipped` frames in: it reports the frames left, so the voice ends
    /// with the file; a loop goes back to the file's start.
    private final class SkippedDecoder: AudioDecoder {
        let base: AudioDecoder
        private var remaining: Int?
        init(_ base: AudioDecoder, skipped: Int) {
            self.base = base
            remaining = base.frameCount.map { max($0 - skipped, 0) }
        }
        var channelCount: Int { base.channelCount }
        var sampleRate: Double { base.sampleRate }
        var frameCount: Int? { remaining }
        func read(into buffer: UnsafeMutablePointer<Float>, frames: Int) throws -> Int { try base.read(into: buffer, frames: frames) }
        func rewind() throws {
            try base.rewind()
            remaining = base.frameCount
        }
    }

    /// Plays `source` from `offset` seconds in, once or looping; false when the editor has no
    /// audio device or the file can't be read. A file starting part way in begins once its
    /// decoder has skipped there (in the background; `playingAsset` already names it).
    @MainActor @discardableResult
    static func play(_ source: Source, volume: Float = 1, pitch: Float = 1, asset: AssetID? = nil, from offset: Double = 0,
                     loop: Bool = false, duration: Double? = nil, in session: EditorSession) -> Bool {
        guard let audio = session.audioProvider?() else { return false }
        stop()
        voiceAsset = asset
        let offset = max(offset, 0)
        switch source {
        case .build(let build):
            let sound = build.soundBuffer(name: "sfx preview")
            let start = min(Int(offset * sound.sampleRate), max(sound.frameCount - 1, 0))
            let buffer = start == 0 ? sound
                : SoundBuffer(samples: Array(sound.samples[start...]), channelCount: 1, sampleRate: sound.sampleRate, name: "sfx preview")
            // A loop goes round the whole sound: play the rest once, then loop it from the start.
            voice = audio.play(start == 0 || !loop ? buffer : sound, volume: volume, pitch: pitch, loop: loop)
            started = (Date(), start == 0 || !loop ? offset : 0, sound.duration, loop, pitch)
        case .file(let url):
            if offset <= 0 {
                do {
                    voice = try audio.playStream(contentsOf: url, on: audio.sfx, volume: volume, pitch: pitch, loop: loop)
                } catch {
                    session.log.warning("Sound preview: can't play \(url.lastPathComponent): \(error)")
                    return false
                }
                started = (Date(), 0, duration, loop, pitch)
                return true
            }
            generation += 1
            let ticket = generation
            loadingAsset = asset
            started = (Date(), offset, duration, loop, pitch)
            starting = (ticket, volume, pitch, loop, offset, duration, url)
            let mailbox = startMailbox
            Task.detached(priority: .userInitiated) {
                let box: DecoderBox? = try? {
                    let decoder = try AudioFile.decoder(contentsOf: url)
                    var skip = Int(offset * decoder.sampleRate), skipped = 0
                    var scratch = [Float](repeating: 0, count: 8192 * decoder.channelCount)
                    while skip > 0 {
                        let read = try scratch.withUnsafeMutableBufferPointer { try decoder.read(into: $0.baseAddress!, frames: min(skip, 8192)) }
                        if read == 0 { break }
                        skip -= read
                        skipped += read
                    }
                    return DecoderBox(SkippedDecoder(decoder, skipped: skipped))
                }()
                mailbox.post(ticket, box)
            }
            startSession = session
        }
        return true
    }

    @MainActor static func stop() {
        generation += 1
        loadingAsset = nil
        starting = nil
        voice?.stop()
        voice = nil
        voiceAsset = nil
        started = nil
    }
}

extension EditorSession {
    /// Plays the sound `clip` names (a path under `Assets/` or "asset:<id>": an audio file or a
    /// `.sfx`) once as a preview, replacing any preview still playing. False when it names no
    /// sound, no project is open, or the editor has no audio device.
    @discardableResult
    public func previewSound(clip: String, volume: Float = 1, pitch: Float = 1) -> Bool {
        guard let assets, let source = SoundPreview.source(of: clip, in: assets) else { return false }
        return SoundPreview.play(source, volume: volume, pitch: pitch, in: self)
    }

    /// Whether `id` is a sound the preview plays: an audio file (wav, ogg, mp3) or a `.sfx`.
    public func isSoundAsset(_ id: AssetID) -> Bool {
        guard let assets else { return false }
        return SoundPreview.source(of: id, in: assets) != nil
    }

    /// Plays the sound asset `id` (an audio file or a `.sfx`) once as a preview, replacing any
    /// preview still playing. Songs stream from their file. False when `id` isn't a sound or the
    /// editor has no audio device.
    @discardableResult
    public func previewSound(asset id: AssetID, from offset: Double = 0, loop: Bool = false, duration: Double? = nil) -> Bool {
        guard let assets, let source = SoundPreview.source(of: id, in: assets) else { return false }
        return SoundPreview.play(source, asset: id, from: offset, loop: loop, duration: duration, in: self)
    }

    /// The sound asset the preview is playing; nil when none is, or it has ended.
    public var soundPreviewAsset: AssetID? { SoundPreview.playingAsset }

    /// Seconds into the sound the preview is at (the inspector's playhead); nil when none plays.
    public var soundPreviewPlayhead: Double? { SoundPreview.playhead }

    /// Plays the sound asset `id`, or stops it when it is the one playing (its inspector's Play /
    /// Stop). Returns whether it is playing afterwards.
    @discardableResult
    public func toggleSoundPreview(asset id: AssetID, loop: Bool = false, duration: Double? = nil) -> Bool {
        if soundPreviewAsset == id {
            stopSoundPreview()
            return false
        }
        return previewSound(asset: id, loop: loop, duration: duration)
    }

    /// Stops the sound preview, if one is playing.
    public func stopSoundPreview() {
        SoundPreview.stop()
    }
}

extension EditorSession {
    /// Writes a sound build to "`name`.sfx" (or "… 2") in `folder`. Returns its id.
    @discardableResult
    public func createSoundBuildAsset(in folder: String, name: String = "New Sound", build: SoundBuild = .preset(.blip)) -> AssetID? {
        guard let assets, checkAssetPaths([folder, name], "New Sound") else {
            log.error("New Sound: no project is open")
            return nil
        }
        let path = assets.uniquePath(Self.join(folder, name + ".sfx"))
        do {
            let id = try assets.createSoundBuild(build, at: path)
            log.info("Created sound \(path)")
            return id
        } catch {
            log.error("New Sound failed: \(error)")
            return nil
        }
    }

    /// Whether `id` is a `.sfx` file.
    public func isSoundBuildFile(_ id: AssetID) -> Bool {
        assets?.record(id)?.importer == SoundBuildImporter().name
    }

    /// Replaces the contents of the sound build `id` as one undo step. Returns the import's
    /// warnings, nil on failure.
    @discardableResult
    public func applySoundBuild(_ build: SoundBuild, to id: AssetID, label: String = "Edit Sound") -> [String]? {
        guard let assets, let old = assets.soundBuild(of: id) else {
            log.error("\(label): \(id) isn't a readable .sfx file")
            return nil
        }
        guard old != build else { return [] }
        let command = SoundBuildFileEditCommand(asset: id, old: old, new: build, in: assets, label: label)
        guard perform(command) else { return nil }
        return command.warnings.value
    }
}

/// Makes sound build edits undoable: performing writes `new` to the file, reverting writes `old` back.
public struct SoundBuildFileEditCommand: UndoCommand {
    public var label: String
    public let asset: AssetID
    public let old: SoundBuild
    public let new: SoundBuild
    /// The last write's import warnings.
    let warnings = Box<[String]>([])
    private weak var database: AssetDatabase?

    final class Box<T> {
        var value: T
        init(_ value: T) { self.value = value }
    }

    public init(asset: AssetID, old: SoundBuild, new: SoundBuild, in database: AssetDatabase, label: String = "Edit Sound") {
        self.asset = asset
        self.old = old
        self.new = new
        self.database = database
        self.label = label
    }

    public mutating func perform(in world: World) throws { try write(new) }
    public mutating func revert(in world: World) throws { try write(old) }

    private func write(_ build: SoundBuild) throws {
        guard let database else { throw AssetError.noSuchAsset(asset.description) }
        warnings.value = try database.writeSoundBuild(build, to: asset)
    }
}

/// Arguments naming a `.sfx` file.
public protocol SoundBuildTarget {
    var asset: AssetReference? { get }
    var path: String? { get }
}

extension EditorSession {
    /// The sound build named by `target` and its contents.
    func resolveSoundBuild(_ target: some SoundBuildTarget, _ title: String) throws -> (AssetID, SoundBuild) {
        let id = try resolveAsset(target.asset, path: target.path, title)
        guard isSoundBuildFile(id), let build = assets?.soundBuild(of: id) else {
            throw CommandError.failed("\(title): \(assets?.path(of: id) ?? id.description) isn't a readable .sfx file")
        }
        return (id, build)
    }
}

/// What the sound tools return.
public struct SoundBuildResult: Codable, Equatable, Sendable {
    public var asset: AssetID
    public var path: String
    /// Set an AudioEmitter's `clip` to this ("asset:<id>").
    public var clip: AssetReference
    public var build: SoundBuild
    /// Length in seconds.
    public var duration: Float
    /// Peak loudness (0...1) across the sound, for a sense of its shape.
    public var peaks: [Float]
    public var warnings: [String]
    /// Whether the sound was played in the editor (`sfx.play`).
    public var played: Bool?
}

extension SoundBuildResult {
    @MainActor init(_ id: AssetID, _ build: SoundBuild, warnings: [String], played: Bool? = nil, in session: EditorSession) {
        let record = session.assets?.record(id)
        let samples = build.render()
        self.init(asset: id, path: session.assets?.path(of: id) ?? "", clip: AssetReference(id), build: build,
                  duration: Float(samples.count) / Float(max(build.sampleRate, 1)),
                  peaks: build.peaks(count: EditorSoundBuildCommands.peakCount, of: samples),
                  warnings: Array(Set(build.problems() + warnings)).sorted() + (record?.importError.map { ["import failed: \($0)"] } ?? []),
                  played: played)
    }
}

public enum SoundBuildNewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var folder: String?
        /// Default "New Sound" (the file gets ".sfx").
        public var name: String?
        /// Start from a preset (default blip).
        public var preset: SFXPreset?
        /// With a preset: a random variation, the same one for the same seed.
        public var seed: Int?
        /// Or the whole contents (overrides `preset`).
        public var build: SoundBuild?
        public init(folder: String? = nil, name: String? = nil, preset: SFXPreset? = nil, seed: Int? = nil, build: SoundBuild? = nil) {
            self.folder = folder
            self.name = name
            self.preset = preset
            self.seed = seed
            self.build = build
        }
    }

    public static let id: CommandID = "sfx.new"
    public static let title = "New Sound"
    public static let doc = "Writes a .sfx file in `folder` (default: the Assets root): a synthesized sound effect from `preset` (jump, coin, laser, explosion, hit, powerUp, blip) with an optional `seed` for a random variation, or from `build`. It imports as an audio file, so an AudioEmitter's `clip` can point at it. Returns the asset, its parameters, duration, a waveform summary and warnings. Change it with sfx.edit or sfx.set, hear it with sfx.play. " + EditorSoundBuildCommands.formatDoc
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> SoundBuildResult {
        let build = arguments.build ?? .preset(arguments.preset ?? .blip, seed: arguments.seed)
        let id = try session.commands.require(session.createSoundBuildAsset(
            in: arguments.folder ?? "", name: arguments.name ?? "New Sound", build: build), title)
        return SoundBuildResult(id, build, warnings: [], in: session)
    }
}

public enum SoundBuildGetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, SoundBuildTarget {
        public var asset: AssetReference?
        /// Or its path relative to `Assets/`.
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public static let id: CommandID = "sfx.get"
    public static let title = "Get Sound"
    public static let doc = "Reads a .sfx file: every parameter (defaults included), its duration, a waveform summary (peak loudness across the sound) and warnings."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> SoundBuildResult {
        let (id, build) = try session.resolveSoundBuild(arguments, title)
        return SoundBuildResult(id, build, warnings: [], in: session)
    }
}

public enum SoundBuildSetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, SoundBuildTarget {
        public var asset: AssetReference?
        public var path: String?
        /// The new contents. Omitted keys take their defaults, not the file's old values.
        public var build: SoundBuild
        public init(asset: AssetReference? = nil, path: String? = nil, build: SoundBuild) {
            self.asset = asset
            self.path = path
            self.build = build
        }
    }

    public static let id: CommandID = "sfx.set"
    public static let title = "Set Sound"
    public static let doc = "Replaces a .sfx file's whole contents and reimports it. Undoable. For a few changes, sfx.edit is shorter."
    public static let isUndoable = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> SoundBuildResult {
        let (id, _) = try session.resolveSoundBuild(arguments, title)
        let warnings = try session.commands.require(session.applySoundBuild(arguments.build, to: id, label: title), title)
        return SoundBuildResult(id, arguments.build, warnings: warnings, in: session)
    }
}

public enum SoundBuildEditCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, SoundBuildTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Replace the parameters with this preset (typical values; with `seed`, a random variation of it).
        public var preset: SFXPreset?
        /// Replace the parameters with a random variation of `preset` (needs `preset`; the seed
        /// defaults to the file's seed + 1, so repeating the call is predictable).
        public var randomize: Bool?
        /// Move every continuous parameter by up to this fraction (0...1) of its size.
        public var mutate: Float?
        /// Seed for `preset` / `randomize` / `mutate`; the file's `seed` becomes it.
        public var seed: Int?
        /// Fields to change, applied last: e.g. {"frequency": 660, "waveform": "saw"}.
        public var changes: JSONValue?
        public init(asset: AssetReference? = nil, path: String? = nil, preset: SFXPreset? = nil, randomize: Bool? = nil,
                    mutate: Float? = nil, seed: Int? = nil, changes: JSONValue? = nil) {
            self.asset = asset
            self.path = path
            self.preset = preset
            self.randomize = randomize
            self.mutate = mutate
            self.seed = seed
            self.changes = changes
        }
    }

    public static let id: CommandID = "sfx.edit"
    public static let title = "Edit Sound"
    public static let doc = "Changes a .sfx file in one undoable step, in this order: `preset` (load it; `randomize` with `seed` for a variation), `mutate` (jitter every continuous parameter by that fraction), then `changes` (field name → new value). Returns the new parameters, duration, waveform summary and warnings. Hear the result with sfx.play."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> SoundBuildResult {
        let (id, original) = try session.resolveSoundBuild(arguments, title)
        let build = try edited(original, with: arguments)
        let warnings = try session.commands.require(session.applySoundBuild(build, to: id, label: title), title)
        return SoundBuildResult(id, build, warnings: warnings, in: session)
    }

    /// `build` with the edits of `arguments` applied (pure, for tests and the UI).
    public static func edited(_ build: SoundBuild, with arguments: Arguments) throws -> SoundBuild {
        var build = build
        if arguments.randomize == true && arguments.preset == nil { throw CommandError.failed("randomize needs a preset") }
        if let preset = arguments.preset {
            let seed = arguments.seed ?? (arguments.randomize == true ? build.seed &+ 1 : nil)
            let previousSeed = build.seed
            build = .preset(preset, seed: seed)
            if seed == nil { build.seed = previousSeed }
        }
        if let amount = arguments.mutate {
            build = build.mutated(amount: amount, seed: arguments.seed ?? build.seed &+ 1)
        } else if arguments.preset == nil, let seed = arguments.seed {
            build.seed = seed
        }
        if let changes = arguments.changes {
            guard case .object(let fields) = changes else { throw CommandError.failed("changes must be an object of fields") }
            guard var json = try? JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(build)),
                  case .object(var current) = json else { return build }
            for (key, value) in fields { current[key] = value }
            json = .object(current)
            do { build = try JSONDecoder().decode(SoundBuild.self, from: JSONEncoder().encode(json)) } catch {
                throw CommandError.failed("changes: \(error)")
            }
        }
        return build
    }
}

public enum SoundBuildPlayCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, SoundBuildTarget {
        public var asset: AssetReference?
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public static let id: CommandID = "sfx.play"
    public static let title = "Play Sound"
    public static let doc = "Plays a .sfx file once through the editor's audio output (a new preview replaces the one playing). Returns its duration and waveform summary; `played` is false when the editor has no audio device."
    public static let isReadOnly = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> SoundBuildResult {
        let (id, build) = try session.resolveSoundBuild(arguments, title)
        let played = SoundBuildPreview.play(build, in: session)
        return SoundBuildResult(id, build, warnings: played ? [] : ["no audio device: nothing was played"], played: played, in: session)
    }
}

public enum SoundBuildOpenCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, SoundBuildTarget {
        public var asset: AssetReference?
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public static let id: CommandID = "sfx.open"
    public static let title = "Open in Sound Builder"
    public static let doc = "Opens a .sfx file in the editor's Sound Builder tab (waveform view, play button, presets with Randomize and Mutate, and the parameters form) and brings the tab to the front. view.screenshot {source: \"panel\", panel: \"soundBuilder\"} shows it."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        let (id, _) = try session.resolveSoundBuild(arguments, title)
        session.openSoundBuild = id
        session.onOpenSoundBuild?(id)
        return PathResult(path: session.assets?.path(of: id) ?? "")
    }
}
